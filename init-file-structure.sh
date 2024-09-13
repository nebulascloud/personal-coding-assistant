#!/bin/bash

# Prompt for GitHub username if not already set
if [ -z "$GITHUB_USER" ]; then
  read -p "Enter your GitHub username: " GITHUB_USER
fi

# Prompt for repository name or use current directory name
if [ -z "$REPO_NAME" ]; then
  REPO_NAME=$(basename "$PWD")
  echo "Using repository name: $REPO_NAME"
fi

# Construct GitHub repository URL without .git suffix
GITHUB_REPO="https://github.com/$GITHUB_USER/$REPO_NAME"

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

# Create src/index.js
create_file "src/index.js" \
"import React from 'react';
import ReactDOM from 'react-dom';
import App from './App';
import { ThemeProvider, createTheme } from '@mui/material/styles';

const darkTheme = createTheme({
  palette: {
    mode: 'dark',
  },
});

ReactDOM.render(
  <ThemeProvider theme={darkTheme}>
    <App />
  </ThemeProvider>,
  document.getElementById('root')
);
"

# Create src/App.js
create_file "src/App.js" \
"import React from 'react';
import { Container, Box, Typography } from '@mui/material';
import FileExplorer from './components/FileExplorer';
import Chat from './components/Chat';

function App() {
  return (
    <Container maxWidth=\"lg\">
      <Box sx={{ my: 4 }}>
        <Typography variant=\"h4\" align=\"center\" gutterBottom>
          Personal Coding Assistant
        </Typography>
        <FileExplorer />
        <Chat />
      </Box>
    </Container>
  );
}

export default App;
"

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

# Set remote origin if not already set
if ! git remote | grep -q "origin"; then
  echo "Setting remote origin to $GITHUB_REPO"
  git remote add origin "$GITHUB_REPO"
  echo "Remote origin set to $GITHUB_REPO"
else
  echo "Remote origin already set."
fi

# Push to remote repository if it exists
read -p "Do you want to push the initial commit to GitHub? (y/n): " push_response
if [ "$push_response" = "y" ]; then
  git push -u origin master
  echo "Code pushed to GitHub."
else
  echo "Skipping push to GitHub."
fi

echo "Setup complete."