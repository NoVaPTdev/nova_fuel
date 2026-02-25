/* ============================================================
   NOVA Fuel - Modern NUI App
   ============================================================ */

(function() {
    'use strict';

    // ============================================================
    // CONSTANTS
    // ============================================================

    var GAUGE_RADIUS = 54;
    var GAUGE_CIRCUMFERENCE = 2 * Math.PI * GAUGE_RADIUS; // ~339.29

    var FUEL_TYPES = [
        { name: 'Regular', priceMultiplier: 1.0, color: '#a3e635' },
        { name: 'Premium', priceMultiplier: 1.5, color: '#38bdf8' },
    ];

    // ============================================================
    // STATE
    // ============================================================

    var state = {
        currentFuel: 0,
        maxFuel: 100,
        pricePerLiter: 3,
        tankCapacity: 65,
        stationName: 'Posto de Gasolina',
        selectedFuel: 0,
        quantity: 0,       // liters
        maxLiters: 0,
        isDragging: false,
    };

    // ============================================================
    // DOM
    // ============================================================

    var fuelApp = document.getElementById('fuelApp');
    var stationName = document.getElementById('stationName');
    var gaugeCircle = document.getElementById('gaugeCircle');
    var gaugeValue = document.getElementById('gaugeValue');
    var statCurrent = document.getElementById('statCurrent');
    var statAdding = document.getElementById('statAdding');
    var statFinal = document.getElementById('statFinal');
    var sliderTrack = document.getElementById('sliderTrack');
    var sliderFill = document.getElementById('sliderFill');
    var sliderThumb = document.getElementById('sliderThumb');
    var sliderLabel = document.getElementById('sliderLabel');
    var totalPrice = document.getElementById('totalPrice');
    var pricePerLiterLabel = document.getElementById('pricePerLiterLabel');
    var priceRegular = document.getElementById('priceRegular');
    var pricePremium = document.getElementById('pricePremium');
    var btnClose = document.getElementById('btnClose');
    var btnFill = document.getElementById('btnFill');
    var btnRefuel = document.getElementById('btnRefuel');
    var fuelTypeRegular = document.getElementById('fuelTypeRegular');
    var fuelTypePremium = document.getElementById('fuelTypePremium');

    // ============================================================
    // NUI
    // ============================================================

    function post(event, data) {
        fetch('https://nova_fuel/' + event, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {}),
        }).catch(function() {});
    }

    // ============================================================
    // HELPERS
    // ============================================================

    function litersToPercent(liters) {
        return (liters / state.tankCapacity) * 100;
    }

    function getGaugeColor(pct) {
        if (pct > 60) return '#a3e635';
        if (pct > 30) return '#facc15';
        return '#ef4444';
    }

    function getCurrentPrice() {
        return state.pricePerLiter * FUEL_TYPES[state.selectedFuel].priceMultiplier;
    }

    // ============================================================
    // UI UPDATE
    // ============================================================

    function updateUI() {
        var liters = state.quantity;
        var fuelAdd = litersToPercent(liters);
        var fuelFinal = Math.min(100, state.currentFuel + fuelAdd);
        var price = liters * getCurrentPrice();

        // Gauge
        var offset = GAUGE_CIRCUMFERENCE - (fuelFinal / 100) * GAUGE_CIRCUMFERENCE;
        var color = getGaugeColor(fuelFinal);
        gaugeCircle.setAttribute('stroke-dashoffset', offset.toFixed(2));
        gaugeCircle.setAttribute('stroke', color);
        gaugeCircle.style.filter = 'drop-shadow(0 0 6px ' + color + '66)';
        gaugeValue.textContent = Math.floor(fuelFinal) + '%';

        // Stats
        statCurrent.textContent = Math.floor(state.currentFuel) + '%';
        statAdding.textContent = '+' + Math.floor(fuelAdd) + '%';
        statFinal.textContent = Math.floor(fuelFinal) + '%';

        // Slider
        var pct = state.maxLiters > 0 ? (liters / state.maxLiters) * 100 : 0;
        sliderFill.style.width = pct + '%';
        sliderThumb.style.left = pct + '%';
        sliderLabel.textContent = liters + 'L';

        // Price
        totalPrice.textContent = price.toFixed(2);
        var unitPrice = getCurrentPrice();
        pricePerLiterLabel.textContent = '$' + unitPrice.toFixed(2) + ' por litro';
    }

    function updateFuelTypePrices() {
        var regular = state.pricePerLiter * FUEL_TYPES[0].priceMultiplier;
        var premium = state.pricePerLiter * FUEL_TYPES[1].priceMultiplier;
        priceRegular.textContent = '$' + regular.toFixed(2) + '/L';
        pricePremium.textContent = '$' + premium.toFixed(2) + '/L';
    }

    function setSelectedFuelType(idx) {
        state.selectedFuel = idx;
        fuelTypeRegular.classList.toggle('active', idx === 0);
        fuelTypePremium.classList.toggle('active', idx === 1);
        updateUI();
    }

    // ============================================================
    // CUSTOM SLIDER
    // ============================================================

    function sliderFromEvent(e) {
        var rect = sliderTrack.getBoundingClientRect();
        var clientX = e.touches ? e.touches[0].clientX : e.clientX;
        var x = Math.max(0, Math.min(clientX - rect.left, rect.width));
        var val = Math.round((x / rect.width) * state.maxLiters);
        if (val !== state.quantity) {
            state.quantity = val;
            updateUI();
        }
    }

    sliderTrack.addEventListener('mousedown', function(e) {
        e.preventDefault();
        state.isDragging = true;
        sliderThumb.classList.add('dragging');
        sliderFromEvent(e);
    });

    document.addEventListener('mousemove', function(e) {
        if (state.isDragging) {
            e.preventDefault();
            sliderFromEvent(e);
        }
    });

    document.addEventListener('mouseup', function() {
        if (state.isDragging) {
            state.isDragging = false;
            sliderThumb.classList.remove('dragging');
        }
    });

    // ============================================================
    // FUEL TYPE BUTTONS
    // ============================================================

    fuelTypeRegular.addEventListener('click', function() { setSelectedFuelType(0); });
    fuelTypePremium.addEventListener('click', function() { setSelectedFuelType(1); });

    // ============================================================
    // ACTION BUTTONS
    // ============================================================

    btnClose.addEventListener('click', function() {
        closeUI();
    });

    btnFill.addEventListener('click', function() {
        state.quantity = state.maxLiters;
        updateUI();
    });

    btnRefuel.addEventListener('click', function() {
        if (state.quantity <= 0) return;
        var fuelAdd = litersToPercent(state.quantity);
        var price = Math.ceil(state.quantity * getCurrentPrice());
        post('refuel', {
            amount: fuelAdd,
            price: price,
            liters: state.quantity,
            fuelType: FUEL_TYPES[state.selectedFuel].name,
        });
    });

    // ESC
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeUI();
        }
    });

    function closeUI() {
        fuelApp.classList.add('hidden');
        post('closeFuel');
    }

    // ============================================================
    // NUI MESSAGE HANDLER
    // ============================================================

    window.addEventListener('message', function(event) {
        var data = event.data;
        if (!data || !data.action) return;

        if (data.action === 'open') {
            state.currentFuel = data.currentFuel || 0;
            state.maxFuel = data.maxFuel || 100;
            state.pricePerLiter = data.pricePerLiter || 3;
            state.tankCapacity = data.tankCapacity || 65;
            state.stationName = data.stationName || 'Posto de Gasolina';
            state.quantity = 0;
            state.selectedFuel = 0;

            // Calc max liters
            var fuelNeeded = state.maxFuel - state.currentFuel;
            state.maxLiters = Math.ceil((fuelNeeded / 100) * state.tankCapacity);
            if (state.maxLiters < 0) state.maxLiters = 0;

            // Set label
            stationName.textContent = state.stationName;

            // Reset fuel type
            setSelectedFuelType(0);
            updateFuelTypePrices();

            // Init gauge
            gaugeCircle.setAttribute('stroke-dasharray', GAUGE_CIRCUMFERENCE.toFixed(2));

            // Show
            fuelApp.classList.remove('hidden');
            updateUI();
        }

        if (data.action === 'close') {
            fuelApp.classList.add('hidden');
        }
    });

})();
