/**
 * NOTE: This class is auto generated by OpenAPI Generator (https://openapi-generator.tech) (7.4.0).
 * https://openapi-generator.tech
 * Do not edit the class manually.
 */
package org.openapitools.api;

import org.openapitools.model.LegalActionInitiationRequest;
import io.swagger.v3.oas.annotations.ExternalDocumentation;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.Parameters;
import io.swagger.v3.oas.annotations.media.ArraySchema;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.multipart.MultipartFile;

import javax.validation.Valid;
import javax.validation.constraints.*;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import javax.annotation.Generated;

@Generated(value = "org.openapitools.codegen.languages.SpringCodegen", date = "2024-04-19T17:24:41.195299+05:30[Asia/Kolkata]", comments = "Generator version: 7.4.0")
@Validated
@Tag(name = "legal-action", description = "the legal-action API")
public interface LegalActionApi {

    default Optional<NativeWebRequest> getRequest() {
        return Optional.empty();
    }

    /**
     * POST /legal-action
     *
     * @param legalActionInitiationRequest  (required)
     * @return OK (status code 200)
     */
    @Operation(
        operationId = "legalActionInitiation",
        responses = {
            @ApiResponse(responseCode = "200", description = "OK", content = {
                @Content(mediaType = "text/plain", schema = @Schema(implementation = String.class))
            })
        }
    )
    @RequestMapping(
        method = RequestMethod.POST,
        value = "/legal-action",
        produces = { "text/plain" },
        consumes = { "application/json" }
    )
    
    default ResponseEntity<String> legalActionInitiation(
        @Parameter(name = "LegalActionInitiationRequest", description = "", required = true) @Valid @RequestBody LegalActionInitiationRequest legalActionInitiationRequest
    ) {
        if (legalActionInitiationRequest == null || legalActionInitiationRequest.getCardLast4() == null || legalActionInitiationRequest.getCardLast4().length() != 4) {
            // If the request is invalid, return a 400 Bad Request response
            return new ResponseEntity<>(HttpStatus.BAD_REQUEST);
        } else {
            return new ResponseEntity<>(HttpStatus.OK);
        }


    }

}