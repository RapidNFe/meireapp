module.exports = {
  apps : [{
    name: "MEIRE-GATEWAY",
    script: "./server.js",
    watch: true,
    env: {
      NODE_ENV: "production",
      PORT: 3000
    }
  }, {
    name: "MEIRE-ROBO",
    script: "./robo_noturno.js",
    cron_restart: "0 3 * * *", // Reinicia/Garante execução às 03h
    autorestart: false
  }]
}
