package pt.psoft.g1.psoftg1.shared.model;
import org.owasp.html.PolicyFactory;
import org.owasp.html.Sanitizers;
import org.springframework.util.StringUtils;

import java.util.regex.Pattern;

public class StringUtilsCustom {
    /**
     * @see <a href="https://owasp.org/www-project-java-html-sanitizer/">OWASP Java HTML Sanitizer</a>
     */
    private static final PolicyFactory sanitizer = Sanitizers.FORMATTING.and(Sanitizers.LINKS);

    /**
     * Devolve {@code true} se todos os caracteres forem letras (maiúsculas ou minúsculas), números
     * ou espaços.
     * <p>Neste padrão:
     *
     *     <p>- '{@code \\p{L}}' corresponde a qualquer letra Unicode, incluindo letras com diacríticos.
     *     <p>- '{@code 0-9}' corresponde a qualquer dígito entre 0 e 9.
     *     <p>- '{@code \\s}' corresponde a qualquer espaço.
     * <p>Adaptado de <a href="https://www.baeldung.com/java-check-string-contains-only-letters-numbers">baeldung.com</a>
     * @param str string a comparar
     */
    public static boolean isAlphanumeric(String str){
        String pattern = "^[\\p{L}0-9\\s'-]*$";
        return Pattern.matches(pattern, str);
    }

    public static boolean startsOrEndsInWhiteSpace(String str) {
        return !str.startsWith(" ") && !str.endsWith(" ");
    }

    /**
     * Remove elementos e atributos que possam introduzir scripts, mantendo a formatação e as
     * hiperligações permitidas pelo sanitizador OWASP.
     * <p>Usar este método antes de guardar ou apresentar HTML gerado pelo utilizador; o valor
     * sanitizado reduz o risco de Cross-Site Scripting (XSS).</p>
     * @param str O conteúdo HTML a sanitizar.
     * @return Uma versão sanitizada do conteúdo HTML, sem elementos e atributos potencialmente perigosos.
     * @see <a href="https://owasp.org/www-project-java-html-sanitizer/">OWASP Java HTML Sanitizer</a>
     * @see <a href="https://github.com/OWASP/java-html-sanitizer/">OWASP Java HTML Sanitizer GitHub</a>
     */
    public static String sanitizeHtml(String str){
        return sanitizer.sanitize(str);
    }

}
