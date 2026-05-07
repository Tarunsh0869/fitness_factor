using FirebaseAdmin.Messaging;

namespace fitness_factor_api.Services;

public class FirebaseService
{
    public async Task SendExitConfirmationAsync(string fcmToken, int sessionId)
    {
        var message = new Message
        {
            Token = fcmToken,
            Notification = new Notification
            {
                Title = "Did you leave the gym?",
                Body  = "Tap to confirm your check-out."
            },
            Data = new Dictionary<string, string>
            {
                { "action",     "exit_confirmation" },
                { "session_id", sessionId.ToString() }
            },
            Android = new AndroidConfig
            {
                Priority = Priority.High,
                Notification = new AndroidNotification
                {
                    ChannelId = "geo_attendance",
                    Priority  = NotificationPriority.MAX
                }
            },
            Apns = new ApnsConfig
            {
                Aps = new Aps
                {
                    Sound           = "default",
                    ContentAvailable = true
                }
            }
        };

        await FirebaseMessaging.DefaultInstance.SendAsync(message);
    }
}
