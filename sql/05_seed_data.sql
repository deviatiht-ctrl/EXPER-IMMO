INSERT INTO public.agents (nom,prenom,slug,titre,email,telephone,whatsapp,specialites,langues,experience_ans,actif,ordre)
VALUES
  ('Jean-Baptiste','Marie','marie-jean-baptiste','Directrice des Ventes',
   'marie@experimmo.ht','+509 3700-0001','+509 3700-0001',
   ARRAY['Vente résidentielle','Villa','Terrain'],
   ARRAY['Créole','Français','Anglais'],8,TRUE,1),

  ('Pierre','Marc','marc-pierre','Agent Senior',
   'marc@experimmo.ht','+509 3700-0002','+509 3700-0002',
   ARRAY['Location','Appartement','Bureau'],
   ARRAY['Créole','Français'],5,TRUE,2),

  ('Louis','Sandra','sandra-louis','Agent Immobilier',
   'sandra@experimmo.ht','+509 3700-0003','+509 3700-0003',
   ARRAY['Commercial','Terrain','Investissement'],
   ARRAY['Créole','Français','Espagnol'],3,TRUE,3);

INSERT INTO public.proprietes
  (titre,slug,description_courte,prix,devise,type_transaction,type_propriete,
   zone_id,adresse,latitude,longitude,superficie_m2,superficie_terrain,
   nb_chambres,nb_salles_bain,nb_garages,annee_construction,meuble,
   amenagements,statut,est_vedette,est_nouveau,tags,agent_id)
VALUES
  ('Villa Moderne avec Piscine — Laboule 12',
   'villa-moderne-piscine-laboule',
   'Magnifique villa 4 chambres avec piscine, vue panoramique, générateur et sécurité 24h.',
   350000,'USD','vente','villa',
   (SELECT id FROM public.zones WHERE slug='laboule'),
   'Laboule 12, Route de Kenscoff',18.5228,-72.3184,
   420,800,4,3,2,2018,FALSE,
   ARRAY['Piscine','Générateur','Sécurité 24h','Jardin','Terrasse','Climatisation','Internet Fibre'],
   'disponible',TRUE,FALSE,
   ARRAY['villa','piscine','vue','laboule'],
   (SELECT id FROM public.agents WHERE slug='marie-jean-baptiste')),

  ('Appartement Meublé 3 Ch — Pétion-Ville',
   'appartement-meuble-petion-ville',
   'Bel appartement 3 chambres meublé, résidence sécurisée avec parking et vue dégagée.',
   1800,'USD','location','appartement',
   (SELECT id FROM public.zones WHERE slug='petion-ville'),
   'Rue Geffrard, Pétion-Ville',18.5133,-72.2858,
   180,NULL,3,2,1,2020,TRUE,
   ARRAY['Sécurité 24h','Parking','Climatisation','Balcon','Ascenseur','Internet'],
   'disponible',TRUE,TRUE,
   ARRAY['appartement','meublé','pétion-ville'],
   (SELECT id FROM public.agents WHERE slug='marc-pierre')),

  ('Terrain Résidentiel 1500m² — Kenscoff',
   'terrain-kenscoff-1500m2',
   'Terrain plat en zone calme, vue montagne, route goudronnée, titre de propriété clair.',
   95000,'USD','vente','terrain',
   (SELECT id FROM public.zones WHERE slug='kenscoff'),
   'Route de Kenscoff Km 12',18.5390,-72.3045,
   NULL,1500,0,0,0,NULL,FALSE,ARRAY[]::TEXT[],
   'disponible',FALSE,TRUE,
   ARRAY['terrain','kenscoff','investissement'],
   (SELECT id FROM public.agents WHERE slug='sandra-louis')),

  ('Local Commercial 200m² — Delmas 75',
   'local-commercial-delmas-75',
   'Espace commercial idéal, grande vitrine sur rue principale, parking disponible.',
   2500,'USD','location','local_commercial',
   (SELECT id FROM public.zones WHERE slug='delmas'),
   'Delmas 75, Boulevard principal',18.5502,-72.3021,
   200,NULL,0,1,3,2015,FALSE,
   ARRAY['Parking','Climatisation','Sécurité','Générateur','Grande vitrine'],
   'disponible',FALSE,FALSE,
   ARRAY['commercial','delmas','bureau'],
   (SELECT id FROM public.agents WHERE slug='marc-pierre'));
