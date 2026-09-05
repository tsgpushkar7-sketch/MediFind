const express = require('express');
const router = express.Router();
const Request = require('../models/Request');

router.get('/peak-hours', async (req, res) => {
  try {
    const result = await Request.aggregate([
      {
        $group: {
          _id: { $hour: { date: '$createdAt', timezone: 'Asia/Kolkata' } },
          count: { $sum: 1 },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Demand trend: count of requests grouped by item name
router.get('/demand-trend', async (req, res) => {
  try {
    const result = await Request.aggregate([
      {
        $group: {
          _id: '$itemText',
          count: { $sum: 1 },
        },
      },
      { $sort: { count: -1 } },
    ]);

    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;