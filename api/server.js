require('dotenv').config();
const express = require('express');
const { Pool } = require('pg');
const cors = require('cors');

const app = express();
const port = process.env.PORT || 3000;

// Configuration de la base de données
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

app.use(cors());
app.use(express.json());

// Route pour obtenir l'énergie restante d'une maison
app.get('/api/house/:houseNumber/energy', async (req, res) => {
  try {
    const { houseNumber } = req.params;
    const result = await pool.query(
      'SELECT remaining_energy FROM houses WHERE house_number = $1',
      [houseNumber]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Maison non trouvée' });
    }

    res.json({ 
      house_number: parseInt(houseNumber),
      remaining_energy: parseFloat(result.rows[0].remaining_energy)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Route pour mettre à jour l'énergie restante (ESP32)
app.post('/api/house/:houseNumber/energy/update', async (req, res) => {
  try {
    const { houseNumber } = req.params;
    const { remaining_energy } = req.body;

    const result = await pool.query(
      'UPDATE houses SET remaining_energy = $1 WHERE house_number = $2 RETURNING *',
      [remaining_energy, houseNumber]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Maison non trouvée' });
    }

    res.json({
      house_number: parseInt(houseNumber),
      remaining_energy: parseFloat(result.rows[0].remaining_energy),
      last_update: result.rows[0].last_update
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  }
});

// Route pour recharger l'énergie d'une maison (Propriétaire)
app.post('/api/house/:houseNumber/energy/recharge', async (req, res) => {
  const client = await pool.connect();
  try {
    const { houseNumber } = req.params;
    const { amount } = req.body;

    await client.query('BEGIN');

    // Mettre à jour l'énergie de la maison
    const updateResult = await client.query(
      'UPDATE houses SET remaining_energy = remaining_energy + $1 WHERE house_number = $2 RETURNING *',
      [amount, houseNumber]
    );

    if (updateResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Maison non trouvée' });
    }

    // Enregistrer la recharge
    await client.query(
      'INSERT INTO energy_recharges (house_id, amount) VALUES ((SELECT id FROM houses WHERE house_number = $1), $2)',
      [houseNumber, amount]
    );

    await client.query('COMMIT');

    res.json({
      house_number: parseInt(houseNumber),
      remaining_energy: parseFloat(updateResult.rows[0].remaining_energy),
      recharged_amount: parseFloat(amount),
      last_update: updateResult.rows[0].last_update
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error(err);
    res.status(500).json({ error: 'Erreur serveur' });
  } finally {
    client.release();
  }
});

app.listen(port, () => {
  console.log(`Serveur démarré sur le port ${port}`);
});
