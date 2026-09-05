const mongoose = require('mongoose');

const responseSchema = new mongoose.Schema({
  requestId: { type: mongoose.Schema.Types.ObjectId, ref: 'Request', required: true },
  shopId: { type: mongoose.Schema.Types.ObjectId, ref: 'Shop', required: true },
  priceInfo: { type: String },
  status: { type: String, enum: ['accepted', 'rejected'], default: 'accepted' },
}, { timestamps: true });
responseSchema.index({ requestId: 1, shopId: 1 }, { unique: true });
module.exports = mongoose.model('Response', responseSchema);