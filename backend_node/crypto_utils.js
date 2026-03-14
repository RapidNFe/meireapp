const crypto = require('crypto');
require('dotenv').config();

const MASTER_KEY_HEX = process.env.MASTER_KEY_AES;
if (!MASTER_KEY_HEX || MASTER_KEY_HEX.length !== 64) {
    console.error("❌ ERRO GRAVE: MASTER_KEY_AES não configurada corretamente. O sistema não pode encriptar os certificados.");
    process.exit(1);
}

const MASTER_KEY = Buffer.from(MASTER_KEY_HEX, 'hex');

function encrypt(text) {
    if (!text) return null;
    try {
        const iv = crypto.randomBytes(12); // Padrão recomendado para GCM (96 bits)
        const cipher = crypto.createCipheriv('aes-256-gcm', MASTER_KEY, iv);
        
        let encrypted = cipher.update(text, 'utf8', 'hex');
        encrypted += cipher.final('hex');
        
        const authTag = cipher.getAuthTag().toString('hex');
        
        // Formato final: IV : AuthTag : TextoCifrado
        return `${iv.toString('hex')}:${authTag}:${encrypted}`;
    } catch (err) {
        console.error("❌ Erro ao criptografar senha:", err.message);
        return null;
    }
}

function decrypt(encryptedText) {
    if (!encryptedText) return null;
    
    // Fallback de transição: Se a senha no banco não possui o ':'
    // significa que ela ainda não foi criptografada (plain-text).
    if (!encryptedText.includes(':')) {
        return encryptedText;
    }
    
    const parts = encryptedText.split(':');
    if (parts.length !== 3) return encryptedText;

    try {
        const iv = Buffer.from(parts[0], 'hex');
        const authTag = Buffer.from(parts[1], 'hex');
        const cipherText = parts[2];

        const decipher = crypto.createDecipheriv('aes-256-gcm', MASTER_KEY, iv);
        decipher.setAuthTag(authTag);

        let decrypted = decipher.update(cipherText, 'hex', 'utf8');
        decrypted += decipher.final('utf8');
        
        return decrypted;
    } catch (err) {
        console.error("❌ Erro ao descriptografar senha (Chave violada ou erro GCM):", err.message);
        return null; // Chave violada!
    }
}

module.exports = {
    encrypt,
    decrypt
};
