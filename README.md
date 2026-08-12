Home to [The Hacker Recipes](thehacker.recipes) project :v:

Source files in [docs/src](/docs/src)

You can self-host the website using the included Dockerfile:

```bash
git clone https://github.com/The-Hacker-Recipes/The-Hacker-Recipes.git
cd The-Hacker-Recipes

docker build --pull --tag the-hacker-recipes:latest .

docker run -d \
  --name the-hacker-recipes \
  --restart unless-stopped \
  -p 127.0.0.1:8080:8080 \
  the-hacker-recipes:latest
```

The website will then be available at http://127.0.0.1:8080