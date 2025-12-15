import { BookOpen } from "lucide-react"
import { LoginForm } from "@/components/login-form"
import Banner1 from "@/assets/banners/banner1.webp"
import { createPageUrl } from "@/lib/utils"

export default function Authentification() {
  return (
    <div className="grid min-h-svh lg:grid-cols-2">
      <div className="flex flex-col gap-4 p-6 md:p-10">
        <div className="flex justify-center gap-2 md:justify-start">
          <a href={createPageUrl()} className="flex items-center gap-2 font-medium">
            <div className="w-10 h-10 rounded-xl bg-linear-to-br from-[#1e3a5f] to-[#2d5a8f] text-primary-foreground flex size-6 items-center justify-center">
              <BookOpen className="w-5 h-5" />
            </div>
            <p className="text-lg font-bold gradient-text">
              BiblioTech
            </p>
          </a>
        </div>
        <div className="flex flex-1 items-center justify-center">
          <div className="w-full max-w-xs">
            <LoginForm />
          </div>
        </div>
      </div>
      <div className="bg-muted relative hidden lg:block">
        <img
          src={Banner1}
          alt="Banner1"
          className="absolute inset-0 h-full w-full object-cover dark:brightness-[0.2] dark:grayscale"
        />
      </div>
    </div>
  )
}