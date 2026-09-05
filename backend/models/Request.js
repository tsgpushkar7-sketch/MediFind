const mongoose = require('mongoose');

const requestSchema = new mongoose.Schema({
  customerId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  category: { type: String, enum: ['medical', 'grocery', 'hardware'], required: true },
  itemText: { type: String, required: true },
  itemImageUrl: { type: String },
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point',
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      required: true,
    },
  },
  status: { type: String, enum: ['open', 'resolved', 'cancelled'], default: 'open' },
  selectedShopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', default: null },
}, { timestamps: true });

requestSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Request', requestSchema);