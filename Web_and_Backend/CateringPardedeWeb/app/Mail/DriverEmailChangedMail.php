<?php

namespace App\Mail;

use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class DriverEmailChangedMail extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $oldEmail;
    public $newEmail;
    public $changeDateTime;
    public $ipAddress;

    /**
     * Create a new message instance.
     */
    public function __construct(User $user, string $oldEmail, string $newEmail)
    {
        $this->user = $user;
        $this->oldEmail = $oldEmail;
        $this->newEmail = $newEmail;
        $this->changeDateTime = now()->timezone('Asia/Jakarta')->format('d M Y, H:i');
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: 'Pemberitahuan Keamanan: Email Driver Diperbarui - Pardede Catering',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.driver_email_changed',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
