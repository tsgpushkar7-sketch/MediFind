const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  service: 'gmail',
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