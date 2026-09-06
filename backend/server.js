require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const userRoutes = require('./routes/userRoutes');
const app = express();
app.use(cors());
const shopRoutes = require('./routes/shopRoutes');
const requestRoutes = require('./routes/requestRoutes');
const responseRoutes = require('./routes/responseRoutes');
const chatRoutes = require('./routes/chatRoutes');
const ratingRoutes = require('./routes/ratingRoutes');
const analyticsRoutes = require('./routes/analyticsRoutes');

app.use(express.json());
app.use('/api/users', userRoutes);
app.use('/api/shops', shopRoutes);
app.use('/api/requests', requestRoutes);
app.use('/api/responses', responseRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/ratings', ratingRoutes);
app.use('/api/analytics', analyticsRoutes);
app.get('/', (req, res) => {
  res.send('MediFind backend is running!');
});

const mongoUri = process.env.MONGO_URI;

mongoose.connect(mongoUri, { serverSelectionTimeoutMS: 10000 })
  .then(() => console.log('MongoDB connected successfully'))
  .catch((err) => {
    console.error('MongoDB connection error:', err.message);

    if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEOUT') {
      console.error('MongoDB DNS lookup failed. If you use mongodb+srv, switch to the standard mongodb:// seed-list URI or fix DNS SRV lookups on this network.');
    } else if (err.name === 'MongooseServerSelectionError') {
      console.error('MongoDB host lookup succeeded, but the driver could not reach Atlas. Check Atlas Network Access IP allowlist, VPN/firewall settings, and outbound TCP port 27017.');
    }
  });

const PORT = process.env.PORT || 5000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server is running on port ${PORT}`);
});
