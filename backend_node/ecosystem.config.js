module.exports = {
  apps : [{
    name: "MEIRE-GATEWAY",
    script: "./server.js",
    watch: false, // JAMAIS watch em produção (causa lentidão no deploy)
    max_memory_restart: "400M", // Reinicia se o Gateway vazar memória
    env: {
      NODE_ENV: "production",
      PORT: 3000
    }
  }, {
    name: "MEIRE-ROBO",
    script: "./robo_noturno.js",
    cron_restart: "0 3 * * *", 
    autorestart: false,
    max_memory_restart: "800M" // Robô com Puppeteer consome mais RAM
  }]
}
