from flask import Flask, render_template, request
import dspy
import openai
import chromadb
import os
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import requests
from bs4 import BeautifulSoup
import traceback

# Initialize Flask application
app = Flask(__name__)

# Initialize ChromaDB
client = chromadb.Client()
collection = client.create_collection(name="local_docs")

# Define the embedding function using OpenAI API
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

# Web scraping using DuckDuckGo as a fallback
def duckduckgo_scrape(query):
    url = f"https://duckduckgo.com/html/?q={query}"
    headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
    }
    response = requests.get(url, headers=headers)
    soup = BeautifulSoup(response.text, 'html.parser')

    results = []
    for a in soup.find_all('a', class_='result__a', href=True):
        results.append(a.get_text())

    return results

class RetrievalModule(dspy.Module):
    def __init__(self, passages_per_hop=3):
        super().__init__()
        self.passages_per_hop = passages_per_hop

    def forward(self, query):
        # Search ChromaDB
        chroma_results = collection.query(query_texts=[query], n_results=self.passages_per_hop)
        context = []
        if chroma_results:
            context.extend(chroma_results['documents'])
        
        # Web Search using DuckDuckGo Scraper
        try:
            duckduckgo_results = duckduckgo_scrape(query)
            if duckduckgo_results:
                context.extend(duckduckgo_results)
        except Exception as e:
            print(f"Error during DuckDuckGo search: {e}")
        
        return context

# Use DSPy to create a retrieval-augmented generation (RAG) system
class RAG(dspy.Module):
    def __init__(self, num_passages=3):
        super().__init__()
        self.retrieve = RetrievalModule(passages_per_hop=num_passages)
        self.generate_answer = dspy.ChainOfThought("context, question -> answer")

    def forward(self, question):
        context = self.retrieve(question)
        prediction = self.generate_answer(context=context, question=question)
        return dspy.Prediction(context=context, answer=prediction.answer)

# Initialize DSPy with the Retrieval Module and Language Model
dspy.settings.configure(rm=RAG(num_passages=3).retrieve, lm=dspy.OpenAI(model="gpt-3.5-turbo"))

# Ingest local documents into ChromaDB on startup
ingest_files('data/local_docs')

# Start the file watcher for hot reloading
start_file_watcher('data/local_docs')

# DSPy RAG system
rag_system = RAG(num_passages=3)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/automated_analysis', methods=['POST'])
def automated_analysis():
    user_input = request.form['input']
    result = None
    error_trace = None

    try:
        prediction = rag_system.forward(user_input)
        result = prediction.answer
    except Exception as e:
        error_trace = traceback.format_exc()

    return render_template('index.html', result=result, error_trace=error_trace)

if __name__ == '__main__':
    app.run(debug=True)
