## Customize Makefile settings for scao
## 
## If you need to customize your Makefile, make
## changes here rather than in the main Makefile
#================================================
#================================================

## ----------------------------------------
## Slim & Annotations
## ----------------------------------------

## creating the scao module
## the list of terms curated is collated into a text format file (scao_terms) then used to extract these terms from the efo-edit.owl file to
## enable concurrent updates and sync with efo.owl.
## the updates helps to reflect the updates in the ontologies i.e. NCIt, CL, UBERON, etc that were used in creating this ontology.

scao_Bot.owl: $(IMPORTSDIR)efo-edit_import.owl $(IMPORTSDIR)efo-edit_terms.tsv
	$(ROBOT) extract -i $(IMPORTSDIR)efo-edit_import.owl -T $(IMPORTSDIR)efo-edit_terms.tsv --method BOT -o $@



## creating the slim
## SPARQL query
## extracts the URIs and attaches inSubset scao_slim annotation to each term

scao-slim.owl: scao_Bot.owl
	$(ROBOT) query -i scao_Bot.owl --format ttl --construct $(SPARQLDIR)slim_construct.sparql scao-slim.owl



### Merging ttl with template terms, resulting in the slim annotation of "pdx_slim" being applied to the terms
### no term annotations are added at this point

#scao-prefixed.owl: scao_Bot.owl scao-slim.owl
#		$(ROBOT) merge -i scao_Bot.owl -i scao-slim.owl --prefix $(PREFIX) -o $@





## -- import targets --

$(IMPORTSDIR)efo-edit_import.owl:
	curl https://raw.githubusercontent.com/EBISPOT/efo/master/src/ontology/efo-edit.owl > imports/efo-edit_import.owl



# ----------------------------------------
# Main release targets
# ----------------------------------------

# by default we use Elk to perform a reason-relax-reduce chain
# after that we annotate the ontology with the release versionInfo
$(SRC): scao_Bot.owl scao-slim.owl
	$(ROBOT) merge -i scao_Bot.owl -i scao-slim.owl --prefix $(PREFIX) -o $@

$(ONT).owl: $(SRC)
	$(ROBOT) reason --input $< --reasoner ELK \
		 relax \
		 reduce -r ELK \
		 remove --select imports \
	         merge  $(patsubst %, -i %, $(IMPORT_OWL_FILES))  \
	         annotate --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@

# requires robot 1.2
$(ONT)-base.owl: $(SRC)
	$(ROBOT) remove --trim false --input $< --select imports \
annotate --ontology-iri $(ONTBASE)/$@ --version-iri $(ONTBASE)/releases/$(TODAY)/$@ --output $@ &&\
	echo "$(ONT)-base.owl successfully created."











