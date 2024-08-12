import os
import openai
import chromadb
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Initialize ChromaDB
client = chromadb.Client()
collection = client.create_collection(name="local_docs")

# Define the embedding function
def compute_embeddings(text):
    response = openai.Embedding.create(
        input=text,
        model="text-embedding-ada-002"
    )
    return response['data'][0]['embedding']

# Ingest files into ChromaDB
def ingest_files(directory):
    for filename in os.listdir(directory):
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            embedding = compute_embeddings(content)
            collection.add(
                documents=[content],
                metadatas=[{"filename": filename}],
                ids=[filename],
                embeddings=[embedding]
            )

# Hot reload: Watch for changes in the directory and update ChromaDB
class FileChangeHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.is_directory:
            return
        filepath = event.src_path
        filename = os.path.basename(filepath)
        with open(filepath, 'r', encoding='utf-8') as file:
            content = file.read()
            embedding = compute_embeddings(content)
            collection.update(
                documents=[content],
                metadatas=[{"filename": filename}],
                ids=[filename],
                embeddings=[embedding]
            )

    def on_created(self, event):
        self.on_modified(event)

    def on_deleted(self, event):
        if event.is_directory:
            return
        filename = os.path.basename(event.src_path)
        collection.delete(ids=[filename])

# Start the file watcher
def start_file_watcher(directory):
    event_handler = FileChangeHandler()
    observer = Observer()
    observer.schedule(event_handler, path=directory, recursive=False)
    observer.start()
