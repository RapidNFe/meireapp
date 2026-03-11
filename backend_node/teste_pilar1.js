const serproAuth = require('./serpro_auth');

async function testarCofre() {
    console.log("▶️ Chamada 1: O cliente clica para emitir nota...");
    await serproAuth.getTokens(); // Vai bater no governo

    console.log("\n▶️ Chamada 2: 3 segundos depois, outro cliente emite nota...");
    await serproAuth.getTokens(); // Tem que puxar da memória!
}

testarCofre();
