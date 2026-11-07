import './style.css'
export const metadata = { title: 'primeTrack', description: 'Train. Track. Progress.', applicationName:'primeTrack', appleWebApp:{capable:true,title:'primeTrack',statusBarStyle:'default'} }
export default function RootLayout({children}:{children:React.ReactNode}) {return <html lang="en"><body>{children}</body></html>}
