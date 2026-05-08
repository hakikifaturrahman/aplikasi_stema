const fs = require('fs');

const file = 'database.json';
const data = JSON.parse(fs.readFileSync(file, 'utf8'));

const players = [
  { no: 1, pos: 'GK', nama: 'Thibaut Courtois' },
  { no: 2, pos: 'RB', nama: 'Dani Carvajal' },
  { no: 3, pos: 'CB', nama: 'Éder Militão' },
  { no: 4, pos: 'CB', nama: 'David Alaba' },
  { no: 5, pos: 'AMF', nama: 'Jude Bellingham' },
  { no: 6, pos: 'CMF', nama: 'Eduardo Camavinga' },
  { no: 7, pos: 'LW', nama: 'Vinícius Júnior' },
  { no: 8, pos: 'CMF', nama: 'Federico Valverde' },
  { no: 10, pos: 'CF', nama: 'Kylian Mbappé' },
  { no: 11, pos: 'RW', nama: 'Rodrygo' },
  { no: 12, pos: 'RB', nama: 'T. Alexander-Arnold' },
  { no: 13, pos: 'GK', nama: 'Andriy Lunin' },
  { no: 14, pos: 'DMF', nama: 'Aurélien Tchouaméni' },
  { no: 15, pos: 'AMF', nama: 'Arda Güler' },
  { no: 16, pos: 'CF', nama: 'Gonzalo García' },
  { no: 17, pos: 'CB', nama: 'Raúl Asencio' },
  { no: 18, pos: 'LB', nama: 'Álvaro Carreras' },
  { no: 19, pos: 'CMF', nama: 'Dani Ceballos' },
  { no: 20, pos: 'LB', nama: 'Fran García' },
  { no: 21, pos: 'SS', nama: 'Brahim Díaz' },
  { no: 22, pos: 'CB', nama: 'Antonio Rüdiger' },
  { no: 23, pos: 'LB', nama: 'Ferland Mendy' },
  { no: 24, pos: 'CB', nama: 'Dean Huijsen' },
  { no: 30, pos: 'SS', nama: 'Franco Mastantuono' }
];

data.playersData = players.map(p => ({
  nama: p.nama,
  no: p.no,
  pos: p.pos,
  stamina: 100,
  status: 'Aktif',
  attributes: {
    speed: 80,
    shooting: 80,
    passing: 80,
    defensive: 80,
    vision: 80,
    stamina: 100,
    dribbling: 80
  }
}));

fs.writeFileSync(file, JSON.stringify(data, null, 2));
console.log('Database updated successfully');
