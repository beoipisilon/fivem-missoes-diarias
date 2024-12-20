const app = {
    init: function(data) {
        document.querySelector(".tablet-container").style.display = "block";
        let missionsTable = document.querySelector(".missions-table");
        missionsTable.innerHTML = `
            <tr>
                <th>Missão</th>
                <th>Status</th>
                <th>Recompensa</th>
                <th>Ações</th>
            </tr>
        `;

        console.log(JSON.stringify(data), '14');
        data.missions.forEach(mission => {
            let row = document.createElement("tr");
            let status = mission.available ? "Disponível" : "Indisponível";
            if (mission.claimed) {
                status = "Resgatado";
            }
            row.innerHTML = `
                <td>${mission.label}</td>
                <td>${status}</td>
                <td>${mission.reward ? "$" + mission.reward : "N/A"}</td>
                <td>
                    <button class="action-mission" onclick="${mission.completed ? 'app.claimMission' : 'app.startMission'}(${mission.id})" ${mission.claimed || !mission.available ? 'style="opacity: 0.5;"' : ''}>${mission.completed ? 'Resgatar Recompensa' : 'Iniciar Missão'}</button>
                </td>
            `;
            missionsTable.appendChild(row);
        });
    },
    close: function() {
        document.querySelector(".tablet-container").style.display = "none";
    },
    post: (url, data = {}, mock) => {
        const resourceName = window.GetParentResourceName ? GetParentResourceName() : 'fivem-missoes-diarias';
        if (mock && !window.invokeNative) {
          return mock;
        }
        return fetch(`https://${resourceName}/${url}`, { method: 'POST', body: JSON.stringify(data) })
          .then(res => res.json());
    },
    claimMission: function(mission_id) {
        console.log('claimMission mission')
        app.post('claimMission', { id: mission_id });
    },
    startMission: function(mission_id) {
        console.log('start mission')
        app.post('startMission', { id: mission_id });
    }
}

window.addEventListener('message', ({data}) => {
    if (data.type === 'init') app.init(data);
    if (data.type === 'close') app.close();
})