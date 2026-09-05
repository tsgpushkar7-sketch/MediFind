const express = require('express');
const router = express.Router();
const Shop = require('../models/Shop');

// Register a new shop
router.post('/create', async (req, res) => {
  try {
    const newShop = new Shop(req.body);
    const savedShop = await newShop.save();
    res.status(201).json(savedShop);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});
// Find nearby approved, open shops by category
router.get('/nearby', async (req, res) => {
  try {
    const { longitude, latitude, category, maxDistance } = req.query;

    const shops = await Shop.find({
      category: category,
      status: 'approved',
      isOpen: true,
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: [parseFloat(longitude), parseFloat(latitude)],
          },
          $maxDistance: maxDistance ? parseInt(maxDistance) : 3000,
        },
      },
    });

    res.status(200).json(shops);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// Block a customer from this shop
router.patch('/:shopId/block', async (req, res) => {
  try {
    const { customerId } = req.body;

    const updatedShop = await Shop.findByIdAndUpdate(
      req.params.shopId,
      { $addToSet: { blockedCustomers: customerId } },
      { new: true }
    );

    if (!updatedShop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    res.status(200).json(updatedShop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Unblock a customer from this shop
router.patch('/:shopId/unblock', async (req, res) => {
  try {
    const { customerId } = req.body;

    const updatedShop = await Shop.findByIdAndUpdate(
      req.params.shopId,
      { $pull: { blockedCustomers: customerId } },
      { new: true }
    );

    if (!updatedShop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    res.status(200).json(updatedShop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// Toggle shop open/closed status
router.patch('/:shopId/toggle-open', async (req, res) => {
  try {
    const shop = await Shop.findById(req.params.shopId);
    if (!shop) return res.status(404).json({ error: 'Shop not found' });

    shop.isOpen = !shop.isOpen;
    await shop.save();

    res.status(200).json(shop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// Get the shop owned by a specific user
router.get('/owner/:ownerId', async (req, res) => {
  try {
    const shop = await Shop.findOne({ ownerId: req.params.ownerId });
    if (!shop) {
      return res.status(404).json({ error: 'No shop found for this owner' });
    }
    res.status(200).json(shop);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
module.exports = router;