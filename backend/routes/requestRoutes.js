const express = require('express');
const router = express.Router();
const Request = require('../models/Request');
const admin = require('../firebaseAdmin');
const Shop = require('../models/Shop');
const User = require('../models/User');

router.post('/create', async (req, res) => {
  try {
    const newRequest = new Request(req.body);
    const savedRequest = await newRequest.save();
    res.status(201).json(savedRequest);

    

    // Notify matching shops in the background (don't block the response)
    notifyMatchingShops(savedRequest).catch((err) =>
      console.error('Notification error:', err.message)
    );
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
});

async function notifyMatchingShops(request) {
  if (!admin) return; // Skip if Firebase isn't configured
  const matchingShops = await Shop.find({
    category: request.category,
    status: 'approved',
    isOpen: true,
    blockedCustomers: { $ne: request.customerId },
    location: {
      $near: {
        $geometry: {
          type: 'Point',
          coordinates: request.location.coordinates,
        },
        $maxDistance: 3000,
      },
    },
  });

  for (const shop of matchingShops) {
    const owner = await User.findById(shop.ownerId);

    if (owner && owner.fcmToken) {
      try {
        await admin.messaging().send({
          token: owner.fcmToken,
          notification: {
            title: 'New Request Nearby!',
            body: `Someone needs: ${request.itemText}`,
          },
          data: {
            requestId: request._id.toString(),
          },
        });
        console.log(`Notification sent to ${shop.shopName}`);
      } catch (err) {
        console.error(`Failed to notify ${shop.shopName}:`, err.message);
      }
    }
  }
}
// Customer selects a shop, closing the request for others
router.patch('/:requestId/select', async (req, res) => {
  try {
    const { shopId } = req.body;

    const updatedRequest = await Request.findByIdAndUpdate(
      req.params.requestId,
      {
        selectedShopId: shopId,
        status: 'resolved',
      },
      { new: true }
    );

    if (!updatedRequest) {
      return res.status(404).json({ error: 'Request not found' });
    }

    res.status(200).json(updatedRequest);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
// Get open requests visible to a specific shop (same category, within radius, not blocked)
router.get('/for-shop/:shopId', async (req, res) => {
  try {
    const Shop = require('../models/Shop');
    const Response = require('../models/Response');
    const shop = await Shop.findById(req.params.shopId);

    if (!shop) {
      return res.status(404).json({ error: 'Shop not found' });
    }

    const maxDistance = req.query.maxDistance ? parseInt(req.query.maxDistance) : 3000;

    const requests = await Request.find({
      category: shop.category,
      status: 'open',
      customerId: { $nin: shop.blockedCustomers },
      location: {
        $near: {
          $geometry: {
            type: 'Point',
            coordinates: shop.location.coordinates,
          },
          $maxDistance: maxDistance,
        },
      },
    });

    // Find which of these requests this shop has already responded to
    const requestIds = requests.map((r) => r._id);
    const existingResponses = await Response.find({
      shopId: req.params.shopId,
      requestId: { $in: requestIds },
    });
    const respondedRequestIds = existingResponses.map((r) => r.requestId.toString());

    const requestsWithStatus = requests.map((r) => ({
      ...r.toObject(),
      alreadyResponded: respondedRequestIds.includes(r._id.toString()),
    }));

    res.status(200).json(requestsWithStatus);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get all requests made by a specific customer, newest first
router.get('/customer/:customerId', async (req, res) => {
  try {
    const requests = await Request.find({ customerId: req.params.customerId })
      .sort({ createdAt: -1 });

    res.status(200).json(requests);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;