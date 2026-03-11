class CatracaSerpro {
    constructor(limiteConcorrencia = 3, maxRetentativas = 3) {
        this.fila = [];
        this.processando = 0;
        this.limite = limiteConcorrencia;
        this.maxRetentativas = maxRetentativas;
    }

    adicionar(tarefaFunc) {
        return new Promise((resolve, reject) => {
            this.fila.push({ tarefaFunc, resolve, reject, tentativa: 0 });
            this.processarProximo();
        });
    }

    async processarProximo() {
        if (this.processando >= this.limite || this.fila.length === 0) return;

        this.processando++;
        const item = this.fila.shift();
        const { tarefaFunc, resolve, reject, tentativa } = item;

        try {
            const resultado = await tarefaFunc();
            resolve(resultado);
            this.liberarVaga();
        } catch (erro) {
            const proximaTentativa = tentativa + 1;

            if (proximaTentativa <= this.maxRetentativas) {
                // Cálculo de Backoff: 2s, 4s, 8s...
                const espera = Math.pow(2, proximaTentativa) * 1000;
                
                console.warn(`⚠️ [RETRY] Falha no Serpro. Tentativa ${proximaTentativa}/${this.maxRetentativas}. Aguardando ${espera/1000}s...`);
                
                setTimeout(() => {
                    // Coloca de volta no INÍCIO da fila para priorizar quem já está esperando
                    this.fila.unshift({ ...item, tentativa: proximaTentativa });
                    this.processando--; // Libera a vaga temporariamente enquanto espera o delay
                    this.processarProximo();
                }, espera);
            } else {
                console.error(`❌ [FATAL] Esgotadas as ${this.maxRetentativas} tentativas para esta nota.`);
                reject(erro);
                this.liberarVaga();
            }
        }
    }

    liberarVaga() {
        this.processando--;
        this.processarProximo();
    }
}

module.exports = new CatracaSerpro();
