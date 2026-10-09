import nodemailer from 'nodemailer';

import { env } from '../config/env.js';

let transporter;

async function sendWithBrevoApi({ email, name, code }) {
  const response = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      accept: 'application/json',
      'api-key': env.BREVO_API_KEY,
      'content-type': 'application/json',
    },
    body: JSON.stringify({
      sender: { name: 'FITTRACK', email: env.EMAIL_FROM },
      to: [{ email, name }],
      subject: 'Código de verificación de FITTRACK',
      textContent: `Hola ${name}, tu código de verificación de FITTRACK es: ${code}. Tiene una vigencia de 10 minutos.`,
      htmlContent: `<p>Hola ${name},</p><p>Tu código de verificación de FITTRACK es:</p><h2>${code}</h2><p>Este código tiene una vigencia de 10 minutos.</p>`,
    }),
    signal: AbortSignal.timeout(15000),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`Brevo API rechazó el correo (${response.status}): ${details.slice(0, 300)}`);
  }
}

function getTransporter() {
  if (!env.EMAIL_USER || !env.EMAIL_PASSWORD || !env.EMAIL_FROM) {
    throw new Error('La configuración SMTP de Brevo está incompleta.');
  }

  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.EMAIL_HOST,
      port: env.EMAIL_PORT,
      secure: env.EMAIL_PORT === 465,
      auth: {
        user: env.EMAIL_USER,
        pass: env.EMAIL_PASSWORD,
      },
    });
  }

  return transporter;
}

export async function sendVerificationEmail({ email, name, code }) {
  if (env.BREVO_API_KEY) {
    await sendWithBrevoApi({ email, name, code });
    return;
  }

  await getTransporter().sendMail({
    from: `FITTRACK <${env.EMAIL_FROM}>`,
    to: email,
    subject: 'Código de verificación de FITTRACK',
    text: `Hola ${name}, tu código de verificación de FITTRACK es: ${code}. Tiene una vigencia de 10 minutos.`,
    html: `<p>Hola ${name},</p><p>Tu código de verificación de FITTRACK es:</p><h2>${code}</h2><p>Este código tiene una vigencia de 10 minutos.</p>`,
  });
}
