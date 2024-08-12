from flask import Flask, render_template, request, send_file
import os
import dspy
import openai
import re
import random

app = Flask(__name__)

# Set up OpenAI API Key
openai.api_key = os.getenv("OPENAI_API_KEY")

# Configure DSPy Retrieval Model (RM) with ColBERTv2
rm = dspy.ColBERTv2(url='http://20.102.90.50:2017/wiki17_abstracts')

# Configure DSPy settings (we'll set the LM temperature dynamically in the class)
dspy.settings.configure(rm=rm)

def citations_check(paragraph):
    """
    Improved citation check function.
    This checks for patterns that match your expected citation format.
    """
    # Example: Check for brackets like [1], [2], etc., or (Author, Year)
    if re.search(r'\[\d+\]', paragraph):  # Matches [1], [2], etc.
        return True
    if re.search(r'\(\w+, \d{4}\)', paragraph):  # Matches (Author, 2024), etc.
        return True
    return False

# Define a DSPy module for environmental analysis with random temperature
class AdvancedEnvironmentalAnalysis(dspy.Module):
    def __init__(self, passages_per_hop=3):
        super().__init__()
        self.retrieve = dspy.Retrieve(k=passages_per_hop)
        self.generate_query = dspy.ChainOfThought("context, question -> query")
        self.generate_report = dspy.ChainOfThought("context, question -> report")

    def forward(self, question):
        context = []
        
        # Generate a random temperature between 0.5 and 1.0
        random_temperature = random.uniform(0.01, 0.1)
        
        # Configure DSPy Language Model (LM) with OpenAI GPT-3.5-turbo and random temperature
        lm = dspy.OpenAI(model='gpt-3.5-turbo', temperature=random_temperature)
        
        # Update DSPy settings with the new LM configuration
        dspy.settings.configure(lm=lm)
        
        for hop in range(2):
            query = self.generate_query(context=context, question=question).query
            context += self.retrieve(query).passages
        
        # Generate the report using DSPy ChainOfThought
        report = self.generate_report(context=context, question=question)
        
        try:
            # Attempt the suggestion check
            dspy.Suggest(
                citations_check(report.report),  # Use the correct attribute
                "Each section should have proper citations: ‘text... [x].’"
            )
        except dspy.primitives.assertions.DSPySuggestionError as e:
            # Handle the error (e.g., log it, notify user, etc.)
            print(f"Suggestion error encountered: {e}")
        
        return report.report  # Return the correct attribute

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/automated_analysis', methods=['POST'])
def automated_analysis():
    user_input = request.form['input']
    analysis_result = AdvancedEnvironmentalAnalysis().forward(user_input)

    output_file_path = "analysis_result.txt"
    with open(output_file_path, 'w') as file:
        file.write(analysis_result)

    return send_file(output_file_path, as_attachment=True, download_name="analysis_result.txt")

if __name__ == '__main__':
    app.run(debug=True)
