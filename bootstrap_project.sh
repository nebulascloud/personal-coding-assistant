#!/bin/bash

# Get the GitHub username from the global git configuration
GITHUB_USER=$(git config --get user.name)

# Use the current directory name as the repository name
REPO_NAME=$(basename "$PWD")
echo "Using repository name: $REPO_NAME"

# Construct the GitHub repository URL
GITHUB_REPO="https://github.com/$GITHUB_USER/$REPO_NAME.git"

# Function to create a directory if it doesn't exist
create_directory() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo "Created directory: $1"
  else
    echo "Directory $1 already exists."
  fi
}

# Function to create a file if it doesn't exist
create_file() {
  if [ ! -f "$1" ]; then
    echo "$2" > "$1"
    echo "Created file: $1"
  else
    echo "File $1 already exists."
  fi
}

# Check if package.json exists
if [ -f "package.json" ]; then
  echo "package.json exists. Proceeding with directory and file creation."
else
  echo "package.json does not exist. Please run 'npm init' or ensure package.json exists."
  exit 1
fi

# Create necessary directories
create_directory "public"
create_directory "src/components"

# Create index.html in public folder
create_file "public/index.html" \
"<!DOCTYPE html>
<html lang=\"en\">
<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
  <title>Personal Coding Assistant</title>
</head>
<body>
  <div id=\"root\"></div>
</body>
</html>"

# Create main.js in root
create_file "main.js" \
"const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true,
      contextIsolation: false
    },
  });

  win.loadFile('public/index.html');
}

app.whenReady().then(createWindow);

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
"

# Create src/App.js with "Hello World" code
create_file "src/App.js" \
"import React from 'react';
import './App.css';

function App() {
  return (
    <div className=\"App\">
      <h1>Hello World!</h1>
      <p>This is a simple React application running inside a Docker container.</p>
    </div>
  );
}

export default App;
"

# Create src/App.css with dark-themed styles
create_file "src/App.css" \
"/* src/App.css */
.App {
  text-align: center;
  margin-top: 50px;
  font-family: Arial, sans-serif;
  background-color: #121212;
  color: #ffffff;
  min-height: 100vh;
}

h1 {
  color: #bb86fc;
}

p {
  color: #ffffff;
}
"

# Create src/index.js
create_file "src/index.js" \
"import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const container = document.getElementById('root');
const root = ReactDOM.createRoot(container);
root.render(<App />);
"
echo "Created src/index.js with React 18 syntax."

# Create .env file
create_file ".env" \
"# Add your environment variables here
OPENAI_API_KEY=your_openai_api_key
"

# Create .gitignore
create_file ".gitignore" \
"node_modules
.env
build
/dist
.DS_Store
coverage
npm-debug.log*
yarn-error.log*
package-lock.json
"

# Create a README.md file
if [ ! -f "README.md" ]; then
  echo "# $REPO_NAME" > README.md
  echo "README.md file created."
else
  echo "README.md already exists."
fi

# Create Dockerfile
if [ ! -f "Dockerfile" ]; then
  cat <<EOL > Dockerfile
# Dockerfile

# Stage 1: Build the React app
FROM node:16-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

# Stage 2: Serve the React app with Nginx
FROM nginx:stable-alpine

COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
EOL
  echo "Dockerfile created."
else
  echo "Dockerfile already exists."
fi

# Create docker-compose.yml
if [ ! -f "docker-compose.yml" ]; then
  cat <<EOL > docker-compose.yml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "3000:80"
    container_name: personal-coding-assistant
EOL
  echo "docker-compose.yml file created."
else
  echo "docker-compose.yml already exists."
fi

echo "All files and directories have been created."

# Initialize Git repository if it doesn't exist
if [ ! -d ".git" ]; then
  echo "Initializing Git repository..."
  git init
  git add .
  git commit -m "Initial commit"
  echo "Git repository initialized."
else
  echo "Git repository already exists."
fi

# Check if GitHub CLI is installed and create remote repo if needed
if command -v gh &> /dev/null; then
  echo "GitHub CLI is installed."

  # Create repository using GitHub CLI if it doesn't exist
  if ! gh repo view "$GITHUB_USER/$REPO_NAME" &> /dev/null; then
    echo "Creating repository $REPO_NAME on GitHub..."
    gh repo create "$REPO_NAME" --public --source=. --remote=origin || echo "GitHub repository created but remote not added."
  else
    echo "Repository $REPO_NAME already exists on GitHub."
  fi
else
  echo "GitHub CLI not installed. Please install it to create the repository on GitHub or create it manually."
  exit 1
fi

# Explicitly add the remote origin in case GitHub CLI didn't
if ! git remote | grep -q "origin"; then
  echo "Adding remote origin manually..."
  git remote add origin "$GITHUB_REPO"
  echo "Remote origin set to $GITHUB_REPO"
else
  echo "Remote origin already set."
fi

# Get current branch name (main or master)
current_branch=$(git rev-parse --abbrev-ref HEAD)

# Push to remote repository
read -p "Do you want to push the initial commit to GitHub? (y/n): " push_response
if [ "$push_response" = "y" ]; then
  # Attempt to push code
  echo "Pushing code to GitHub..."
  if git push -u origin "$current_branch"; then
    echo "Code successfully pushed to GitHub."
  else
    echo "Failed to push code to GitHub. Please ensure the remote repository exists."
  fi
else
  echo "Skipping push to GitHub."
fi

echo "Setup complete."