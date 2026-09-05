require('dotenv').config();
const mongoose = require('mongoose');
const Request = require('./models/Request');

const items = ['Paracetamol', 'Dolo 650', 'Crocin', 'Azithromycin', 'Cetirizine', 'Vicks Vaporub', 'ORS Powder', 'Amoxicillin'];
const customerId = '6a6aeed6115f053990ecbee6'; // using your existing test user

async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('Connected to MongoDB, seeding data...');

  const fakeRequests = [];

  for (let i = 0; i < 150; i++) {
    // Random date within the last 30 days
    const daysAgo = Math.floor(Math.random() * 30);
    const hoursAgo = Math.floor(Math.random() * 24);
    const fakeDate = new Date();
    fakeDate.setDate(fakeDate.getDate() - daysAgo);
    fakeDate.setHours(hoursAgo, Math.floor(Math.random() * 60));

    // Bias more requests toward evening hours (6-9 PM) to make peak-hour analytics meaningful
    const isEveningBiased = Math.random() < 0.4;
    if (isEveningBiased) {
      fakeDate.setHours(18 + Math.floor(Math.random() * 3));
    }

    const randomItem = items[Math.floor(Math.random() * items.length)];

    fakeRequests.push({
      customerId,
      category: 'medical',
      itemText: randomItem,
      location: {
        coordinates: [73.8567 + (Math.random() - 0.5) * 0.05, 18.5204 + (Math.random() - 0.5) * 0.05],
      },
      status: 'open',
      createdAt: fakeDate,
      updatedAt: fakeDate,
    });
  }

  await Request.insertMany(fakeRequests);
  console.log(`Inserted ${fakeRequests.length} fake requests.`);
  mongoose.disconnect();
}

seed();