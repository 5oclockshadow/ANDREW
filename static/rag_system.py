import dspy
import chromadb
import requests
from bs4 import BeautifulSoup

# Initialize ChromaDB client (reuse the same collection as in file_watcher.py)
client = chromadb.Client()
collection = client.get_collection(name="local_docs")

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
