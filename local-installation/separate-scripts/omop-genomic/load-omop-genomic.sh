#!/usr/bin/env bash
set -e

mkdir -p omop-genomic-voc

echo "Download OMOP Genomic vocabulary"
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/local-installation/separate-scripts/omop-genomic/omop-genomic.zip --output omop-genomic.zip

echo "Unzip OMOP Genomic vocabulary"
unzip omop-genomic.zip -d omop-genomic-voc

docker cp omop-genomic-voc/ postgres:/tmp

echo "Load domain"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_domain AS SELECT * FROM domain LIMIT 0;
          COPY temp_domain FROM '/tmp/omop-genomic-voc/DOMAIN.csv' DELIMITER E'\t' CSV HEADER;
          INSERT INTO domain SELECT * FROM temp_domain WHERE NOT EXISTS (SELECT 1 FROM domain WHERE domain.domain_id = temp_domain.domain_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load concept class"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_concept_class AS SELECT * FROM concept_class LIMIT 0;
          COPY temp_concept_class FROM '/tmp/omop-genomic-voc/CONCEPT_CLASS.csv' DELIMITER E'\t' CSV HEADER;
          INSERT INTO concept_class SELECT * FROM temp_concept_class WHERE NOT EXISTS (SELECT 1 FROM concept_class WHERE concept_class.concept_class_id = temp_concept_class.concept_class_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load vocabulary"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_vocabulary AS SELECT * FROM vocabulary LIMIT 0;
          COPY temp_vocabulary FROM '/tmp/omop-genomic-voc/VOCABULARY.csv' DELIMITER E'\t' CSV HEADER;
          INSERT INTO vocabulary SELECT * FROM temp_vocabulary WHERE NOT EXISTS (SELECT 1 FROM vocabulary WHERE vocabulary.vocabulary_id = temp_vocabulary.vocabulary_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load relationship"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_relationship AS SELECT * FROM relationship LIMIT 0;
          COPY temp_relationship FROM '/tmp/omop-genomic-voc/RELATIONSHIP.csv' DELIMITER E'\t' CSV HEADER;
          INSERT INTO relationship SELECT * FROM temp_relationship WHERE NOT EXISTS (SELECT 1 FROM relationship WHERE relationship.relationship_id = temp_relationship.relationship_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load concepts"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_concept AS SELECT * FROM concept LIMIT 0;
          COPY temp_concept FROM '/tmp/omop-genomic-voc/CONCEPT.csv' DELIMITER E'\t' QUOTE E'\b' CSV HEADER;
          INSERT INTO concept SELECT * FROM temp_concept WHERE NOT EXISTS (SELECT 1 FROM concept WHERE concept.concept_id = temp_concept.concept_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load drug strengths"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_drug_strength AS SELECT * FROM drug_strength LIMIT 0;
          COPY temp_drug_strength FROM '/tmp/omop-genomic-voc/DRUG_STRENGTH.csv' DELIMITER E'\t' QUOTE E'\b' CSV HEADER;
          INSERT INTO drug_strength SELECT * FROM temp_drug_strength WHERE NOT EXISTS (SELECT 1 FROM drug_strength WHERE drug_strength.drug_concept_id = temp_drug_strength.drug_concept_id and drug_strength.ingredient_concept_id = temp_drug_strength.ingredient_concept_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load concept synonyms"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_concept_synonym AS SELECT * FROM concept_synonym LIMIT 0;
          COPY temp_concept_synonym FROM '/tmp/omop-genomic-voc/CONCEPT_SYNONYM.csv' DELIMITER E'\t' QUOTE E'\b' CSV HEADER;
          INSERT INTO concept_synonym SELECT * FROM temp_concept_synonym WHERE NOT EXISTS (SELECT 1 FROM concept_synonym WHERE concept_synonym.concept_id = temp_concept_synonym.concept_id and concept_synonym.concept_synonym_name=temp_concept_synonym.concept_synonym_name);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load concept ancestors"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_concept_ancestor AS SELECT * FROM concept_ancestor LIMIT 0;
          COPY temp_concept_ancestor FROM '/tmp/omop-genomic-voc/CONCEPT_ANCESTOR.csv' DELIMITER E'\t' QUOTE E'\b' CSV HEADER;
          INSERT INTO concept_ancestor SELECT * FROM temp_concept_ancestor WHERE NOT EXISTS (SELECT 1 FROM concept_ancestor WHERE concept_ancestor.ancestor_concept_id = temp_concept_ancestor.ancestor_concept_id and concept_ancestor.descendant_concept_id=temp_concept_ancestor.descendant_concept_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Load concept relationships"
LOAD_STMT="SET search_path = omopcdm;
          CREATE TEMP TABLE temp_concept_relationship AS SELECT * FROM concept_relationship LIMIT 0;
          COPY temp_concept_relationship FROM '/tmp/omop-genomic-voc/CONCEPT_RELATIONSHIP.csv' DELIMITER E'\t' QUOTE E'\b' CSV HEADER;
          INSERT INTO concept_relationship SELECT * FROM temp_concept_relationship WHERE NOT EXISTS (SELECT 1 FROM concept_relationship WHERE concept_relationship.concept_id_1 = temp_concept_relationship.concept_id_1 and concept_relationship.concept_id_2=temp_concept_relationship.concept_id_2 and concept_relationship.relationship_id=temp_concept_relationship.relationship_id);"
docker exec -it postgres psql -U postgres -d OHDSI -t -c "$LOAD_STMT"

echo "Cleanup"
rm -rf omop-genomic-voc
docker exec -it -u $UID postgres bash -c "rm -rf /tmp/omop-genomic-voc"
