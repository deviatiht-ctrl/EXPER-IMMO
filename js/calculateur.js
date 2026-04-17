// calculateur.js
import { formatPrice } from './utils.js';

document.addEventListener('DOMContentLoaded', () => {
    const prixInput = document.getElementById('prix-bien');
    const apportInput = document.getElementById('apport');
    const tauxInput = document.getElementById('taux');
    const dureeInput = document.getElementById('duree');
    const deviseSelect = document.getElementById('devise-calc');

    const mensaliteEl = document.getElementById('mensualite');
    const montantPretEl = document.getElementById('montant-pret');
    const totalInteretsEl = document.getElementById('total-interets');
    const apportPctEl = document.getElementById('apport-pct');

    const btnTableau = document.getElementById('btn-tableau');
    const tableauSection = document.getElementById('tableau-section');
    const tableauBody = document.getElementById('tableau-body');

    let chart = null;

    const calculate = () => {
        const prix = parseFloat(prixInput.value) || 0;
        const apport = parseFloat(apportInput.value) || 0;
        const tauxAnnuel = parseFloat(tauxInput.value) / 100;
        const dureeAnnees = parseFloat(dureeInput.value);
        const devise = deviseSelect.value;

        // Sync values
        document.getElementById('taux-val').textContent = `${tauxInput.value}%`;
        document.getElementById('duree-val').textContent = `${dureeInput.value} ans`;
        const pct = prix > 0 ? Math.round((apport / prix) * 100) : 0;
        apportPctEl.textContent = `${pct}%`;

        const montantPret = Math.max(0, prix - apport);
        const nbMois = dureeAnnees * 12;
        const tauxMensuel = tauxAnnuel / 12;

        let mensualite = 0;
        if (montantPret > 0) {
            if (tauxMensuel === 0) {
                mensualite = montantPret / nbMois;
            } else {
                mensualite = (montantPret * tauxMensuel) / (1 - Math.pow(1 + tauxMensuel, -nbMois));
            }
        }

        const totalPaye = mensualite * nbMois;
        const totalInterets = totalPaye - montantPret;

        // Update UI
        mensualiteEl.textContent = formatPrice(mensualite, devise);
        montantPretEl.textContent = formatPrice(montantPret, devise);
        totalInteretsEl.textContent = formatPrice(totalInterets, devise);

        updateChart(montantPret, totalInterets);
        updateAmortizationTable(montantPret, tauxMensuel, mensualite, devise);
    };

    const updateChart = (capital, interets) => {
        const ctx = document.getElementById('chart-pret').getContext('2d');
        if (chart) chart.destroy();

        chart = new Chart(ctx, {
            type: 'doughnut',
            data: {
                labels: ['Capital', 'Intérêts'],
                datasets: [{
                    data: [capital, interets],
                    backgroundColor: ['#1B4FBB', '#F0A500'],
                    borderWidth: 0
                }]
            },
            options: {
                cutout: '70%',
                plugins: {
                    legend: { position: 'bottom' }
                }
            }
        });
    };

    const updateAmortizationTable = (capital, tauxMensuel, mensualite, devise) => {
        tableauBody.innerHTML = '';
        let solde = capital;
        
        for (let i = 1; i <= Math.min(12, 360); i++) {
            const partInterets = solde * tauxMensuel;
            const partCapital = mensualite - partInterets;
            solde -= partCapital;

            const tr = document.createElement('tr');
            tr.innerHTML = `
                <td>Mois ${i}</td>
                <td>${formatPrice(mensualite, devise)}</td>
                <td>${formatPrice(partCapital, devise)}</td>
                <td>${formatPrice(partInterets, devise)}</td>
                <td>${formatPrice(Math.max(0, solde), devise)}</td>
            `;
            tableauBody.appendChild(tr);
        }
    };

    // Listeners
    [prixInput, apportInput, tauxInput, dureeInput, deviseSelect].forEach(input => {
        input.addEventListener('input', calculate);
    });

    btnTableau.addEventListener('click', () => {
        tableauSection.style.display = tableauSection.style.display === 'none' ? 'block' : 'none';
    });

    calculate();
});
