const crypto = require('crypto');
const path = require('path');
const fs = require('fs');
const envPath = path.resolve(__dirname, '.env');

try {
    const envConfig = require('dotenv').parse(fs.readFileSync(envPath));
    for (const k in envConfig) {
        process.env[k] = envConfig[k];
    }
} catch (err) {
    console.error(`⚠️ Aviso: Não foi possível ler o arquivo .env em ${envPath}`);
}

const MASTER_KEY_HEX = process.env.MASTER_KEY_AES;
if (!MASTER_KEY_HEX) {
    console.error(`❌ ERRO: MASTER_KEY_AES não encontrada no ambiente após tentativa de leitura em: ${envPath}`);
    process.exit(1);
}
if (MASTER_KEY_HEX.length !== 64) {
    console.error("❌ ERRO: MASTER_KEY_AES deve ter 64 caracteres (hex de 32 bytes).");
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
