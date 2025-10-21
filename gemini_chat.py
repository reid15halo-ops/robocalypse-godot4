import os
import google.generativeai as genai

# IMPORTANT: Replace "YOUR_API_KEY" with your actual Google AI Studio API key.
# Get your key from https://aistudio.google.com/app/apikey
try:
    # It's recommended to set the API key as an environment variable for security.
    # If you've set the GOOGLE_API_KEY environment variable, the script will use it.
    # Otherwise, it will use the key hardcoded in the script.
    api_key = os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        api_key = "YOUR_API_KEY" # <-- PASTE YOUR KEY HERE
    
    genai.configure(api_key=api_key)

except Exception as e:
    print(f"Error configuring the API key: {e}")
    print("Please make sure you have set your GOOGLE_API_KEY environment variable or replaced 'YOUR_API_KEY' in the script.")
    exit()

def start_chat():
    """
    Starts an interactive chat session with the Gemini model.
    """
    try:
        # Create the model
        model = genai.GenerativeModel('gemini-pro')
        chat = model.start_chat(history=[])

        print("?? Gemini Chat is ready. Type 'quit' or 'exit' to end the session.")
        print("-" * 30)

        while True:
            prompt = input("You: ")
            if prompt.lower() in ["quit", "exit"]:
                print("?? Goodbye!")
                break
            
            if not prompt:
                continue

            # Send the message and stream the response
            response = chat.send_message(prompt, stream=True)
            
            print("Gemini: ", end="")
            for chunk in response:
                print(chunk.text, end="", flush=True)
            print() # Newline after the full response

    except Exception as e:
        print(f"\nAn error occurred: {e}")
        print("This might be due to an invalid API key or network issues.")

if __name__ == "__main__":
    start_chat()
