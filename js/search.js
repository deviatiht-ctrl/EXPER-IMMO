// search.js

document.addEventListener('DOMContentLoaded', () => {
    const btnMainSearch = document.getElementById('btn-main-search');
    
    if (btnMainSearch) {
        btnMainSearch.addEventListener('click', () => {
            const type = document.querySelector('.search-tabs .tab.active').dataset.type;
            const propertyType = document.getElementById('type-propriete').value;
            const zoneId = document.getElementById('zone').value;
            const prixMax = document.getElementById('prix-max').value;

            // Redirect to search page with params
            const params = new URLSearchParams({
                type: type,
                type_p: propertyType,
                zone: zoneId,
                p_max: prixMax
            });

            window.location.href = `proprietes.html?${params.toString()}`;
        });
    }
});
