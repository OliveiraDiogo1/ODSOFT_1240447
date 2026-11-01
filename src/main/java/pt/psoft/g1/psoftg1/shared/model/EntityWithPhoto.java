package pt.psoft.g1.psoftg1.shared.model;

import jakarta.annotation.Nullable;
import jakarta.persistence.CascadeType;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.OneToOne;
import lombok.Getter;

import java.nio.file.InvalidPathException;
import java.nio.file.Path;

@Getter
@MappedSuperclass
public abstract class EntityWithPhoto {
    @Nullable
    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name="photo_id")
    protected Photo photo;

    // O mapper usa este método para definir a fotografia; setPhotoInternal aplica a alteração.
    public void setPhoto(String photoUri) {
        this.setPhotoInternal(photoUri);
    }

    protected void setPhotoInternal(String photoURI) {
        if (photoURI == null) {
            this.photo = null;
        } else {
            try {
                // A construção de Path com sucesso significa que o URI é válido.
                this.photo = new Photo(Path.of(photoURI));
            } catch (InvalidPathException e) {
                // Um caminho inválido deixa a entidade sem fotografia.
                this.photo = null;
            }
        }
    }
}
