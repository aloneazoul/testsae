import { cn } from "@/lib/utils"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldGroup,
  FieldLabel,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"

export function LoginForm({
  className,
  ...props
}) {
  return (
    <form className={cn("flex flex-col gap-6", className)} {...props}>
      <FieldGroup>
        <div className="flex flex-col items-center gap-1 text-center">
          <h1 className="text-2xl font-bold gradient-text">Connexion à votre compte</h1>
          <p className="text-muted-foreground text-sm text-balance">
            Entrez votre email ci-dessous pour vous connecter à votre compte
          </p>
        </div>
        <Field>
          <FieldLabel htmlFor="email">Email</FieldLabel>
          <Input id="email" type="email" placeholder="email@exemple.com" required />
        </Field>
        <Field>
          <div className="flex items-center">
            <FieldLabel htmlFor="password">Mot de passe</FieldLabel>
          </div>
          <Input id="password" type="password" placeholder="Votre mot de passe" required />
        </Field>
        <Field>
          <Button type="submit">Se connecter</Button>
        </Field>
      </FieldGroup>
    </form>
  );
}
