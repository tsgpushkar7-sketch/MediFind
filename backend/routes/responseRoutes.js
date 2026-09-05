const express = require('express');
const router = express.Router();
const Response = require('../models/Response');
const Request = require('../models/Request');

// Shop accepts a request
router.post('/create', async (req, res) => {
  try {
    const newResponse = new Response(req.body);
    const savedResponse = await newResponse.save();
    res.status(201).json(savedResponse);
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ error: 'You have already responded to this request.' });
    }
    res.status(400).json({ error: error.message });
  }
});

// Get all responses (with shop details) for a specific request
router.get('/request/:requestId', async (req, res) => {
  try {
    const request = await Request.findById(req.params.requestId);

    if (!request) {
      return res.status(404).json({ error: 'Request not found' });
    }

    if (request.status !== 'open') {
      return res.status(200).json({
        message: 'This request has already been resolved or cancelled.',
        responses: [],
      });
    }

    const responses = await Response.find({
      requestId: req.params.requestId,
      status: 'accepted',
    }).populate('shopId');

    res.status(200).json({ responses });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;