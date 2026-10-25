package sn.isep.Convoiturage.vehicule;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import sn.isep.Convoiturage.common.SecurityUtils;
import sn.isep.Convoiturage.vehicule.VehiculeDtos.*;

import java.util.List;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class VehiculeController {

    private final VehiculeService vehicules;
    private final DocumentService documents;

    @PostMapping("/moi/vehicules")
    @ResponseStatus(HttpStatus.CREATED)
    public VehiculeDto declarer(@Valid @RequestBody DeclarationVehiculeRequete req) {
        return vehicules.declarer(SecurityUtils.utilisateurCourantId(), req);
    }

    @GetMapping("/moi/vehicules")
    public List<VehiculeDto> mesVehicules() {
        return vehicules.mesVehicules(SecurityUtils.utilisateurCourantId());
    }

    @PutMapping("/moi/vehicules/{id}")
    public VehiculeDto modifier(@PathVariable Long id, @Valid @RequestBody ModificationVehiculeRequete req) {
        return vehicules.modifier(SecurityUtils.utilisateurCourantId(), id, req);
    }

    @DeleteMapping("/moi/vehicules/{id}")
    public ResponseEntity<Void> desactiver(@PathVariable Long id) {
        vehicules.desactiver(SecurityUtils.utilisateurCourantId(), id);
        return ResponseEntity.noContent().build();
    }

    /** Téléversement multipart : type=PERMIS_CONDUIRE|CARTE_GRISE, idVehicule (carte grise), fichier (JPEG/PNG/PDF, 5 Mo). */
    @PostMapping(value = "/moi/documents", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @ResponseStatus(HttpStatus.CREATED)
    public DocumentDto soumettre(@RequestParam TypeDocument type,
                                 @RequestParam(required = false) Long idVehicule,
                                 @RequestParam("fichier") MultipartFile fichier) {
        return documents.soumettre(SecurityUtils.utilisateurCourantId(), type, idVehicule, fichier);
    }

    @GetMapping("/moi/documents")
    public List<DocumentDto> mesDocuments() {
        return documents.mesDocuments(SecurityUtils.utilisateurCourantId());
    }

    @GetMapping("/documents/{id}/fichier")
    public ResponseEntity<Resource> fichier(@PathVariable Long id) {
        DocumentService.FichierDocument f = documents.fichier(id, SecurityUtils.utilisateurCourantId(), SecurityUtils.estAdmin());
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(f.typeMime()))
                .header(HttpHeaders.CONTENT_DISPOSITION, ContentDisposition.inline()
                        .filename(f.nomOriginal() != null ? f.nomOriginal() : "document").build().toString())
                .header(HttpHeaders.CACHE_CONTROL, "private, no-store")
                .body(f.ressource());
    }
}
