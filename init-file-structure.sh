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
  exit 1
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