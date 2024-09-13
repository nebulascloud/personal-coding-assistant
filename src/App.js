import React from 'react';
import { Container, Box, Typography } from '@mui/material';
import FileExplorer from './components/FileExplorer';
import Chat from './components/Chat';

function App() {
  return (
    <Container maxWidth="lg">
      <Box sx={{ my: 4 }}>
        <Typography variant="h4" align="center" gutterBottom>
          Personal Coding Assistant
        </Typography>
        <FileExplorer />
        <Chat />
      </Box>
    </Container>
  );
}

export default App;
