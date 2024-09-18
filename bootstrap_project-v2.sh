#!/bin/bash

# Set the GitHub username from the global git configuration
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

# Function to create a file with content
create_file() {
  if [ ! -f "$1" ]; then
    echo "$2" > "$1"
    echo "Created file: $1"
  else
    echo "File $1 already exists."
  fi
}

# Create package.json
if [ ! -f "package.json" ]; then
  echo "Creating package.json..."
  cat <<EOL > package.json
{
  "name": "$REPO_NAME",
  "version": "1.0.0",
  "description": "",
  "main": "index.js",
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "electron": "electron ."
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "electron": "^32.1.0"
  },
  "dependencies": {
    "@emotion/react": "^11.13.3",
    "@emotion/styled": "^11.13.0",
    "@mui/material": "^6.1.0",
    "axios": "^1.7.7",
    "dotenv": "^16.4.5",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-scripts": "^5.0.1"
  }
}
EOL
  echo "package.json created."
else
  echo "package.json already exists."
fi

# Install dependencies
echo "Installing dependencies..."
npm install

# Install npm-check-updates globally to update dependencies
echo "Installing npm-check-updates globally..."
npm install -g npm-check-updates

# Update all packages to their latest versions
echo "Updating dependencies to latest versions..."
ncu -u

# Install updated dependencies
echo "Installing updated dependencies..."
npm install

# Create necessary directories
create_directory "public"
create_directory "src"
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

# Create src/App.js with Hello World code
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

# Create src/index.js importing App.css
create_file "src/index.js" \
"import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';

const container = document.getElementById('root');
const root = ReactDOM.createRoot(container);
root.render(<App />);
"

# Create Dockerfile
if [ ! -f "Dockerfile" ]; then
  cat <<EOL > Dockerfile
# Dockerfile

# Stage 1: Build the React app
FROM node:22.8-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm install --production

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

# Check if README.md exists, if not, create it
if [ ! -f "README.md" ]; then
  echo "# $REPO_NAME" > README.md
  echo "README.md file created."
else
  echo "README.md already exists."
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

# Build and run the Docker container using Docker Compose
read -p "Do you want to build and run the Docker container? (y/n): " docker_response
if [ "$docker_response" = "y" ]; then
  echo "Building and running the Docker container..."
  docker-compose up --build -d
  echo "Docker container is up and running. Access the application at http://localhost:3000"
else
  echo "Skipping Docker container build and run."
fi

echo "Setup complete."