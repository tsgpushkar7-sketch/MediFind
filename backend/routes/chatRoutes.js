const express = require('express');
const router = express.Router();
const ChatMessage = require('../models/ChatMessage');

// Send a message
router.post('/create', async (req, res) => {
  try {
    const newMessage = new ChatMessage(req.body);
    const savedMessage = await newMessage.save();
    res.status(201).json(savedMessage);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

// Get all messages for a specific request, in order
router.get('/request/:requestId', async (req, res) => {
  try {
    const messages = await ChatMessage.find({
      requestId: req.params.requestId,
    }).sort({ createdAt: 1 });

    res.status(200).json(messages);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;