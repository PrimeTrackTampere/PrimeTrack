import type { MetadataRoute } from 'next'
export default function manifest(): MetadataRoute.Manifest {
 return {name:'primeTrack',short_name:'primeTrack',description:'Train. Track. Progress.',start_url:'/',display:'standalone',background_color:'#ffffff',theme_color:'#111111',icons:[{src:'/icon.svg',sizes:'any',type:'image/svg+xml',purpose:'any'}]}
}
