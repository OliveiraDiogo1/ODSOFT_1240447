package pt.psoft.g1.psoftg1.system;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import pt.psoft.g1.psoftg1.auth.api.AuthRequest;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("bootstrap")
class SystemTest {

    private static final String LIBRARIAN = "maria@gmail.com";
    private static final String PASSWORD = "Mariaroberta!123";

    @Autowired
    private TestRestTemplate restTemplate;

    @Test
    void loginWithValidCredentialsReturnsToken() {
        var response = restTemplate.postForEntity(
                "/api/public/login",
                jsonEntity(new AuthRequest(LIBRARIAN, PASSWORD)),
                String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getFirst(HttpHeaders.AUTHORIZATION)).isNotBlank();
    }

    @Test
    void loginWithInvalidCredentialsReturnsUnauthorized() {
        var response = restTemplate.postForEntity(
                "/api/public/login",
                jsonEntity(new AuthRequest(LIBRARIAN, "wrong-password")),
                String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void unauthenticatedBookListingReturnsUnauthorized() {
        var response = restTemplate.getForEntity("/api/books", String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void authenticatedBookSearchReturnsSeededBook() {
        var response = restTemplate.exchange(
                "/api/books?title={title}",
                HttpMethod.GET,
                authenticatedEntity(),
                String.class,
                "O País das Pessoas de Pernas Para o Ar");

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("9789720706386");
    }

    @Test
    void authenticatedBookLookupReturnsSeededBook() {
        var response = restTemplate.exchange(
                "/api/books/9789720706386",
                HttpMethod.GET,
                authenticatedEntity(),
                String.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).contains("O País das Pessoas de Pernas Para o Ar");
    }

    private HttpEntity<AuthRequest> jsonEntity(AuthRequest request) {
        var headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        return new HttpEntity<>(request, headers);
    }

    private HttpEntity<Void> authenticatedEntity() {
        var login = restTemplate.postForEntity(
                "/api/public/login",
                jsonEntity(new AuthRequest(LIBRARIAN, PASSWORD)),
                String.class);
        var token = login.getHeaders().getFirst(HttpHeaders.AUTHORIZATION);

        var headers = new HttpHeaders();
        headers.setBearerAuth(token);
        return new HttpEntity<>(headers);
    }
}
