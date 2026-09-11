const nodemailer = require('nodemailer');
const dns = require('dns');

dns.setDefaultResultOrder('ipv4first');

const transporter = nodemailer.createTransport({
  host: 'smtp.gmail.com',
  port: 465,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

async function sendOtpEmail(toEmail, otp) {
  await transporter.sendMail({
    from: `"MediFind" <${process.env.EMAIL_USER}>`,
    to: toEmail,
    subject: 'Verify your MediFind account',
    html: `<h2>Your verification code is: ${otp}</h2><p>This code expires in 10 minutes.</p>`,
  });
}

module.exports = { sendOtpEmail };