"""
GPT Translator
"""


import argparse
import logging
import os
import time

import polib
from dotenv import load_dotenv
from openai import OpenAI

# from python_gpt_po.version import __version__

# Initialize environment variables and logging
load_dotenv()
logging.basicConfig(level=logging.INFO)


class TranslationConfig:
    """ Class to hold configuration parameters for the translation service. """
    def __init__(self, client, model, bulk_mode=False, fuzzy=False, folder_language=False, bulksize=50):  # pylint: disable=R0913
        self.client = client
        self.model = model
        self.bulk_mode = bulk_mode
        self.fuzzy = fuzzy
        self.folder_language = folder_language
        self.bulksize = bulksize


class TranslationService:
    """ Class to encapsulate translation functionalities. """

    def __init__(self, config):
        self.config = config
        self.batch_size = config.bulksize
        self.total_batches = 0

    def validate_openai_connection(self):
        """Validates the OpenAI connection by making a test API call."""
        try:
            test_message = {"role": "system", "content": "Test message to validate connection."}
            self.config.client.chat.completions.create(model=self.config.model, messages=[test_message])
            logging.info("OpenAI connection validated successfully.")
            return True
        except Exception as e:  # pylint: disable=W0718
            logging.error("Failed to validate OpenAI connection: %s", e)
            return False

    def translate_bulk(self, texts, target_language, po_file_path, current_batch):
        translated_texts = []
        total_texts = len(texts)
        for i in range(0, total_texts, self.batch_size):
            batch_texts = texts[i:i + self.batch_size]
            batch_info = f"File: {po_file_path}, Batch {i // self.batch_size + 1}/{self.total_batches}"
            batch_info += f" (texts {i + 1}-{min(i + self.batch_size, total_texts)})"
            translation_request = (f"You are a sphinx translator, when meet words in formula or the word is an exclusive noun in English, such as \"NVIDIA\", \"Isaac Sim\", \"GitHub\", then do not translate. "
                                   "Please be careful not to break reST notation, such as \":ref:`search`\", just keep it. "
                                   "Please follow sphinx syntax. "
                                   "Don't try to answer or explain the words or sentences I give you. "
                                   "Now please translate the following text from English into {target_language}. "
                                   "Add a space between Chinese word/Chinese punctuation and \"`\", for example, \"中文字符 `abc123`_ 中文字符\" instead of \"中文字符`abc123`_中文字符\", \"我好（你也好） `abc123`_ （你也好）我好\" instead of \"我好（你也好）`abc123`_（你也好）我好\". "
                                   "中文和`之间要增加一个空格，并按照收到的格式进行返回"
                                   "Use the format 'Index@Text' for each segment:\n\n")
            for index, text in enumerate(batch_texts, start=i):
                translation_request += f"{index}@{text}\n"

            retries = 3

            while retries:
                try:
                    if self.config.bulk_mode:
                        logging.info("Translating %s", batch_info)
                    self.perform_translation(translation_request, translated_texts, batch=True)
                    break
                except Exception as e:
                    error_message = f"Error in translating {batch_info}: {e}. Retrying... {retries - 1} attempts left."
                    logging.error(error_message)
                    if retries <= 1:
                        logging.error("Maximum retries reached for %s. Skipping this batch.", batch_info)
                        translated_texts.extend([(index, '') for index in range(i, i + len(batch_texts))])
                    retries -= 1
                    time.sleep(1)

        return translated_texts


    def perform_translation(self, translation_request, translated_texts, batch=False):
        message = {"role": "user", "content": translation_request}
        completion = self.config.client.chat.completions.create(model=self.config.model, messages=[message])

        raw_response = completion.choices[0].message.content.strip()
        logging.info(raw_response)

        if batch:
            for line in raw_response.split("\n"):
                try:
                    index_str, translation = line.split("@", 1)
                    index = int(index_str.strip())
                    translation = translation.strip()
                    if translation and not translation.startswith("The provided text does not seem to be"):
                        translated_texts.append((index, translation))
                    else:
                        logging.error("No valid translation found for index %s", index)
                        translated_texts.append((index, ''))
                except ValueError:
                    logging.error("Error parsing line: '%s'", line)
                    translated_texts.append((index, ''))
        else:
            if not raw_response.startswith("The provided text does not seem to be"):
                translated_texts.append((0, raw_response))
            else:
                logging.error("No valid translation found for text")
                translated_texts.append((0, ''))

    def scan_and_process_po_files(self, input_folder, languages):
        """Scans and processes .po files in the given input folder."""
        po_files = []
        
        # First, collect all .po files, excluding the 'api' folder and 'changelog.po' file
        for root, dirs, files in os.walk(input_folder):
            # Exclude 'api' folder
            dirs[:] = [d for d in dirs if d != 'api']
            # Collect .po files excluding 'changelog.po'
            po_files.extend([os.path.join(root, file) for file in files if file.endswith(".po") and file != 'changelog.po'])
        
        total_files = len(po_files)
        
        for idx, po_file_path in enumerate(po_files, start=1):
            logging.info("Discovered .po file: %s", po_file_path)  # Log each discovered file
            self.process_po_file(po_file_path, languages)
            
            # Log progress as completed/total
            logging.info("Progress: %d/%d", idx, total_files)

    def process_po_file(self, po_file_path, languages):
        """Processes an individual .po file by removing fuzzy entries if specified."""
        if self.config.fuzzy:
            self.disable_fuzzy_translations(po_file_path)
        try:
            po_file = polib.pofile(po_file_path)
            file_lang = po_file.metadata.get('Language', '')

            # If language is not in the list, try inferring from any part of the directory
            if not file_lang or file_lang not in languages:
                if self.config.folder_language:
                    folder_parts = po_file_path.split(os.sep)
                    inferred_lang = next((part for part in folder_parts if part in languages), None)
                    logging.info("Attempting to infer language for .po file: %s", po_file_path)
                    if inferred_lang:
                        file_lang = inferred_lang
                        logging.info("Inferred language for .po file: %s as %s", po_file_path, file_lang)
                    else:
                        logging.warning("Skipping .po file due to inferred language mismatch: %s", po_file_path)
                        return
                else:
                    logging.warning("Skipping .po file due to language mismatch: %s", po_file_path)
                    return

            if file_lang in languages:
                # Reload the po file after modifications
                po_file = polib.pofile(po_file_path)
                texts_to_translate = [
                    entry.msgid
                    for entry in po_file
                    if not entry.msgstr and entry.msgid and 'fuzzy' not in entry.flags
                ]
                self.process_translations(texts_to_translate, file_lang, po_file, po_file_path)

                po_file.save(po_file_path)
                logging.info("Finished processing .po file: %s", po_file_path)
        except Exception as e:  # pylint: disable=W0718
            logging.error("Error processing file %s: %s", po_file_path, e)

    def disable_fuzzy_translations(self, po_file_path):
        """
        Disables fuzzy translations in a .po file by removing the 'fuzzy' flags from entries.
        """
        try:
            po_file = polib.pofile(po_file_path)
            fuzzy_entries = [entry for entry in po_file if 'fuzzy' in entry.flags]

            for entry in fuzzy_entries:
                entry.flags.remove('fuzzy')

            po_file.save(po_file_path)
            logging.info("Fuzzy translations disabled in file: %s", po_file_path)
        except Exception as e:  # pylint: disable=W0718
            logging.error("Error while disabling fuzzy translations in file %s: %s", po_file_path, e)

    def process_translations(self, texts, target_language, po_file, po_file_path):
        """Processes translations either in bulk or one by one."""
        if self.config.bulk_mode:
            self.translate_in_bulk(texts, target_language, po_file, po_file_path)
        else:
            self.translate_one_by_one(texts, target_language, po_file, po_file_path)

    def translate_in_bulk(self, texts, target_language, po_file, po_file_path):
        """Translates texts in bulk and applies them to the .po file."""
        self.total_batches = (len(texts) - 1) // 50 + 1
        translated_texts = self.translate_bulk(texts, target_language, po_file_path, 0)
        self.apply_translations_to_po_file(translated_texts, texts, po_file)

    def translate_one_by_one(self, texts, target_language, po_file, po_file_path):
        """Translates texts one by one and updates the .po file."""
        for index, text in enumerate(texts):
            logging.info("Translating text %s/%s in file %s", (index + 1), len(texts), po_file_path)
            logging.info(text)
            translation_request = f"You are a sphinx translator, when meet words in formula or the word is an exclusive noun in English, such as \"NVIDIA\", \"Isaac Sim\", \"GitHub\", then do not translate. Add a space between the Chinese word and \"`\", For example, \"中文字符 `abc123`_ 中文字符\" instead of \"中文字符`abc123`_中文字符\". Please be careful not to break reST notation, such as \":ref:`search`\", just keep it. Please follow sphinx syntax. Don't try to answer or explain the words or sentences I give you. Now please translate the following text from English into {target_language}: {text}"
            translated_texts = []
            self.perform_translation(translation_request, translated_texts, batch=False)
            if translated_texts:
                translated_text = translated_texts[0][1]
                self.update_po_entry(po_file, text, translated_text)
            else:
                logging.error("No translation returned for text: %s", text)

    def update_po_entry(self, po_file, original_text, translated_text):
        """Updates a .po file entry with the translated text."""
        entry = po_file.find(original_text)
        if entry:
            entry.msgstr = translated_text

    def apply_translations_to_po_file(self, translated_texts, original_texts, po_file):
        """
        Applies the translated texts to the .po file.
        """
        text_index_map = dict(enumerate(original_texts))
        translation_map = {}

        for index, translation in translated_texts:
            original_text = text_index_map.get(index)
            if original_text:
                self.update_po_entry(po_file, original_text, translation)
            else:
                logging.warning("No original text found for index %s", index)

        for entry in po_file:
            if entry.msgid in translation_map:
                entry.msgstr = translation_map[entry.msgid]
                logging.info("Applied translation for '%s'", entry.msgid)
            elif not entry.msgstr:
                logging.warning("No translation applied for '%s'", entry.msgid)

        po_file.save()
        logging.info("Po file saved.")


def main():
    """Main function to parse arguments and initiate processing."""
    parser = argparse.ArgumentParser(description="Scan and process .po files")
    # parser.add_argument("--version", action="version", version=f'%(prog)s {__version__}')
    parser.add_argument("--folder", required=True, help="Input folder containing .po files")
    parser.add_argument("--lang", required=True, help="Comma-separated language codes to filter .po files")
    parser.add_argument("--fuzzy", action="store_true", help="Remove fuzzy entries")
    parser.add_argument("--bulk", action="store_true", help="Use bulk translation mode")
    parser.add_argument("--bulksize", type=int, default=50, help="Batch size for bulk translation")
    parser.add_argument("--model", default="gpt-3.5-turbo-1106", help="OpenAI model to use for translations")
    parser.add_argument("--api_key", help="OpenAI API key")
    parser.add_argument("--folder-language", action="store_true", help="Set language from directory structure")

    args = parser.parse_args()

    # Initialize OpenAI client
    # api_key = args.api_key if args.api_key else os.getenv("OPENAI_API_KEY")
    api_key = "sk-g8TUvgtpcIgwXtaC5f463f99D7Dc4425B439Ad9140A5C4C9"
    base_url = 'https://api.gpts.vin/v1'
    client = OpenAI(api_key=api_key, base_url=base_url)

    # Create a configuration object
    config = TranslationConfig(client, args.model, args.bulk, args.fuzzy, args.folder_language, args.bulksize)

    # Initialize the translation service with the configuration object
    translation_service = TranslationService(config)

    # Validate the OpenAI connection
    if not translation_service.validate_openai_connection():
        logging.error("OpenAI connection failed. Please check your API key and network connection.")
        return

    # Extract languages
    languages = [lang.strip() for lang in args.lang.split(',')]
    translation_service.scan_and_process_po_files(args.folder, languages)


if __name__ == "__main__":
    main()
