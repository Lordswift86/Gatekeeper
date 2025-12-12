import { Server } from 'socket.io'
import { Server as HttpServer } from 'http'

export function setupSocket(httpServer: HttpServer) {
    const io = new Server(httpServer, {
        cors: {
            origin: '*', // Configure appropriately in production
            methods: ['GET', 'POST']
        }
    })

    io.on('connection', (socket) => {
        console.log('Client connected:', socket.id)

        // Join room by estate ID
        socket.on('join-estate', (estateId: string) => {
            socket.join(`estate-${estateId}`)
            console.log(`Socket ${socket.id} joined estate-${estateId}`)
        })

        // Intercom - Initiate Call
        socket.on('initiate-call', (data: { targetId: string, initiatorId: string, estateId: string }) => {
            io.to(`estate-${data.estateId}`).emit('incoming-call', data)
        })

        // Intercom - Answer Call
        socket.on('answer-call', (data: { callId: string }) => {
            socket.broadcast.emit('call-answered', data)
        })

        // Intercom - End Call
        socket.on('end-call', (data: { callId: string }) => {
            socket.broadcast.emit('call-ended', data)
        })

        // Chat Messages
        socket.on('send-message', (data: { fromId: string, toId: string, content: string, estateId: string }) => {
            io.to(`estate-${data.estateId}`).emit('new-message', data)
        })

        // Emergency SOS
        socket.on('send-sos', (data: { residentId: string, unitNumber: string, estateId: string }) => {
            io.to(`estate-${data.estateId}`).emit('emergency-alert', data)
        })

        socket.on('disconnect', () => {
            console.log('Client disconnected:', socket.id)
        })
    })

    return io
}
