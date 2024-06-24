from locust import HttpUser, task

class HelloWorldUser(HttpUser):
    @task
    def hello_world(self):
        self.client.post("/completion",json={'model': 'mistral-7b', 'temperature': 0.2, 'prompt': 'Provide all proteins that interact with RAD51', 'logprobs': True,'n_probs':1})
